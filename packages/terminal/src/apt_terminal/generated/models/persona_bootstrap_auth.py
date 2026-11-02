from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.persona_bootstrap_auth_token_class import PersonaBootstrapAuthTokenClass

if TYPE_CHECKING:
    from ..models.persona_bootstrap_subject import PersonaBootstrapSubject


T = TypeVar("T", bound="PersonaBootstrapAuth")


@_attrs_define
class PersonaBootstrapAuth:
    """What the presented token is. A `visitor` token is the anonymous, read-shaped class.

    Attributes:
        token_class (PersonaBootstrapAuthTokenClass):
        subject (PersonaBootstrapSubject):
        expires_at (None | str):
        scope (list[str]):
    """

    token_class: PersonaBootstrapAuthTokenClass
    subject: PersonaBootstrapSubject
    expires_at: None | str
    scope: list[str]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        token_class = self.token_class.value

        subject = self.subject.to_dict()

        expires_at: None | str
        expires_at = self.expires_at

        scope = self.scope

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "tokenClass": token_class,
                "subject": subject,
                "expiresAt": expires_at,
                "scope": scope,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.persona_bootstrap_subject import PersonaBootstrapSubject

        d = dict(src_dict)
        token_class = PersonaBootstrapAuthTokenClass(d.pop("tokenClass"))

        subject = PersonaBootstrapSubject.from_dict(d.pop("subject"))

        def _parse_expires_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        expires_at = _parse_expires_at(d.pop("expiresAt"))

        scope = cast(list[str], d.pop("scope"))

        persona_bootstrap_auth = cls(
            token_class=token_class,
            subject=subject,
            expires_at=expires_at,
            scope=scope,
        )

        persona_bootstrap_auth.additional_properties = d
        return persona_bootstrap_auth

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
