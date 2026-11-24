from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_personas_by_id_tokens_body_subject_kind import (
    PostV1PersonasByIdTokensBodySubjectKind,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1PersonasByIdTokensBodySubject")


@_attrs_define
class PostV1PersonasByIdTokensBodySubject:
    """
    Attributes:
        kind (PostV1PersonasByIdTokensBodySubjectKind): `self` (owner-gated) or `user` (the caller lets the persona act
            AS themselves, gated on the persona’s `may_act user` opt-in) or `team` (owner-gated; the persona acts AS the
            team `id` in the target `ecosystemId`, gated on `may_act team` + persona team-membership + the team’s reach into
            that ecosystem) or `org` (owner-gated; the persona acts AS the organization `id` it is OWNED BY, gated on
            `may_act org` + org-ownership; the acting ecosystem is the org’s own, derived server-side).
        id (str | Unset): The team id for a `team` subject (required for `team`) or the org id for an `org` subject
            (required for `org`). Ignored for `self` (derived from the persona) and `user` (always the authenticated caller,
            never a param).
        ecosystem_id (str | Unset): The TARGET ecosystem a `team` subject acts in (required for `team`); ignored for the
            other kinds (an `org` subject’s ecosystem is derived from the org, never taken from the request).
    """

    kind: PostV1PersonasByIdTokensBodySubjectKind
    id: str | Unset = UNSET
    ecosystem_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        kind = self.kind.value

        id = self.id

        ecosystem_id = self.ecosystem_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "kind": kind,
            }
        )
        if id is not UNSET:
            field_dict["id"] = id
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        kind = PostV1PersonasByIdTokensBodySubjectKind(d.pop("kind"))

        id = d.pop("id", UNSET)

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        post_v1_personas_by_id_tokens_body_subject = cls(
            kind=kind,
            id=id,
            ecosystem_id=ecosystem_id,
        )

        post_v1_personas_by_id_tokens_body_subject.additional_properties = d
        return post_v1_personas_by_id_tokens_body_subject

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
