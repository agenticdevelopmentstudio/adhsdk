from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1PersonasByIdTokensResponse200DataItem")


@_attrs_define
class GetV1PersonasByIdTokensResponse200DataItem:
    """
    Attributes:
        id (str):
        name (str):
        prefix (str): Non-secret leading chars, for display
        created (int): Unix timestamp, in seconds.
        expires_at (None | str):
        last_used_at (None | str): null until the token first authenticates
        persona_id (None | str): The persona this token authenticates AS
        object_ (Literal['token'] | Unset):
    """

    id: str
    name: str
    prefix: str
    created: int
    expires_at: None | str
    last_used_at: None | str
    persona_id: None | str
    object_: Literal["token"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        name = self.name

        prefix = self.prefix

        created = self.created

        expires_at: None | str
        expires_at = self.expires_at

        last_used_at: None | str
        last_used_at = self.last_used_at

        persona_id: None | str
        persona_id = self.persona_id

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "name": name,
                "prefix": prefix,
                "created": created,
                "expires_at": expires_at,
                "last_used_at": last_used_at,
                "persona_id": persona_id,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        name = d.pop("name")

        prefix = d.pop("prefix")

        created = d.pop("created")

        def _parse_expires_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        expires_at = _parse_expires_at(d.pop("expires_at"))

        def _parse_last_used_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_used_at = _parse_last_used_at(d.pop("last_used_at"))

        def _parse_persona_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        persona_id = _parse_persona_id(d.pop("persona_id"))

        object_ = cast(Literal["token"] | Unset, d.pop("object", UNSET))
        if object_ != "token" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'token', got '{object_}'")

        get_v1_personas_by_id_tokens_response_200_data_item = cls(
            id=id,
            name=name,
            prefix=prefix,
            created=created,
            expires_at=expires_at,
            last_used_at=last_used_at,
            persona_id=persona_id,
            object_=object_,
        )

        get_v1_personas_by_id_tokens_response_200_data_item.additional_properties = d
        return get_v1_personas_by_id_tokens_response_200_data_item

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
