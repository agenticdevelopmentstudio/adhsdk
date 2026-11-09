from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_auth_passkey_challenges_response_200_options import (
        PostV1AuthPasskeyChallengesResponse200Options,
    )


T = TypeVar("T", bound="PostV1AuthPasskeyChallengesResponse200")


@_attrs_define
class PostV1AuthPasskeyChallengesResponse200:
    """
    Attributes:
        options (PostV1AuthPasskeyChallengesResponse200Options): PublicKeyCredentialRequestOptionsJSON
        token (str):
        object_ (Literal['auth.passkey_challenge'] | Unset):
    """

    options: PostV1AuthPasskeyChallengesResponse200Options
    token: str
    object_: Literal["auth.passkey_challenge"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        options = self.options.to_dict()

        token = self.token

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "options": options,
                "token": token,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_auth_passkey_challenges_response_200_options import (
            PostV1AuthPasskeyChallengesResponse200Options,
        )

        d = dict(src_dict)
        options = PostV1AuthPasskeyChallengesResponse200Options.from_dict(d.pop("options"))

        token = d.pop("token")

        object_ = cast(Literal["auth.passkey_challenge"] | Unset, d.pop("object", UNSET))
        if object_ != "auth.passkey_challenge" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'auth.passkey_challenge', got '{object_}'")

        post_v1_auth_passkey_challenges_response_200 = cls(
            options=options,
            token=token,
            object_=object_,
        )

        post_v1_auth_passkey_challenges_response_200.additional_properties = d
        return post_v1_auth_passkey_challenges_response_200

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
